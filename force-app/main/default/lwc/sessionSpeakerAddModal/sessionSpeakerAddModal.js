import LightningModal from 'lightning/modal';
import { api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import searchSpeakers from '@salesforce/apex/SessionSpeakerManagerController.searchSpeakers';
import saveSpeaker from '@salesforce/apex/SessionSpeakerManagerController.saveSpeaker';
import saveSessionSpeaker from '@salesforce/apex/SessionSpeakerManagerController.saveSessionSpeaker';

const AVATAR_COLORS = [
    '#1B3A6B', '#4A90D9', '#217346', '#9B59B6',
    '#E67E22', '#C0392B', '#1ABC9C', '#2C3E50'
];

function avatarColor(str) {
    if (!str) return AVATAR_COLORS[0];
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        // eslint-disable-next-line no-bitwise
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function initials(firstName, lastName) {
    return ((firstName || '').charAt(0) + (lastName || '').charAt(0)).toUpperCase() || '?';
}

function enrichSpeaker(spk) {
    const fn = spk.First_Name__c || '';
    const ln = spk.Last_Name__c || '';
    return {
        ...spk,
        initials: initials(fn, ln),
        avatarStyle: `background: ${avatarColor(ln + fn)};`
    };
}

export default class SessionSpeakerAddModal extends LightningModal {
    @api sessionId;

    speakerSearchTerm = null;
    showNewSpeaker = false;
    newSpeaker = {};
    pendingSpeaker = null;
    pendingAssignment = { Role__c: 'Panelist', Order__c: null, Confirmed__c: false };
    isSaving = false;
    _speakerSearchTimeout;

    @wire(searchSpeakers, { searchTerm: '$speakerSearchTerm' })
    _rawSpeakers;

    get speakers() {
        if (this.speakerSearchTerm === null) return { data: null, error: null };
        if (!this._rawSpeakers) return { data: null, error: null };
        if (this._rawSpeakers.error) return this._rawSpeakers;
        if (!this._rawSpeakers.data) return this._rawSpeakers;
        return {
            data: this._rawSpeakers.data.map(enrichSpeaker),
            error: undefined
        };
    }

    get hasSpeakers() {
        return this.speakers.data && this.speakers.data.length > 0;
    }

    get newSpeakerToggleIcon() {
        return this.showNewSpeaker ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get roleOptions() {
        return [
            { label: 'Keynote', value: 'Keynote' },
            { label: 'Panelist', value: 'Panelist' },
            { label: 'Moderator', value: 'Moderator' },
            { label: 'Workshop Leader', value: 'Workshop Leader' }
        ];
    }

    handleSpeakerSearchChange(event) {
        window.clearTimeout(this._speakerSearchTimeout);
        const val = event.target.value || '';
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._speakerSearchTimeout = setTimeout(() => {
            this.speakerSearchTerm = val.length >= 3 ? val : null;
        }, 300);
    }

    disconnectedCallback() {
        window.clearTimeout(this._speakerSearchTimeout);
    }

    toggleNewSpeaker() {
        this.showNewSpeaker = !this.showNewSpeaker;
    }

    handleSpeakerPick(event) {
        const id = event.currentTarget.dataset.id;
        const raw = (this._rawSpeakers.data || []).find(s => s.Id === id);
        if (!raw) return;
        const enriched = enrichSpeaker(raw);
        const fn = enriched.First_Name__c || '';
        const ln = enriched.Last_Name__c || '';
        this.pendingSpeaker = {
            ...enriched,
            fullName: `${fn} ${ln}`.trim()
        };
        this.speakerSearchTerm = null;
    }

    handleSpeakerRowKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleSpeakerPick(event);
        }
    }

    clearPendingSpeaker() {
        this.pendingSpeaker = null;
    }

    handleNewSpeakerFieldChange(event) {
        const field = event.target.name;
        this.newSpeaker = { ...this.newSpeaker, [field]: event.target.value };
    }

    async handleSaveNewSpeaker() {
        if (!this.newSpeaker.Last_Name__c) {
            this._toast('Last Name required', 'Speaker Last Name is required.', 'error');
            return;
        }
        this.isSaving = true;
        try {
            const saved = await saveSpeaker({ speaker: this.newSpeaker });
            this._toast('Speaker created', `${saved.First_Name__c || ''} ${saved.Last_Name__c} has been created.`, 'success');
            const fn = saved.First_Name__c || '';
            const ln = saved.Last_Name__c || '';
            this.pendingSpeaker = {
                Id: saved.Id,
                First_Name__c: fn,
                Last_Name__c: ln,
                Email__c: saved.Email__c,
                fullName: `${fn} ${ln}`.trim(),
                initials: initials(fn, ln),
                avatarStyle: `background: ${avatarColor(ln + fn)};`
            };
            this.showNewSpeaker = false;
            this.newSpeaker = {};
            this.speakerSearchTerm = null;
        } catch (e) {
            this._toast('Error saving speaker', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleAssignmentRoleChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Role__c: event.detail.value };
    }

    handleAssignmentOrderChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Order__c: event.target.value };
    }

    handleAssignmentConfirmedChange(event) {
        this.pendingAssignment = { ...this.pendingAssignment, Confirmed__c: event.target.checked };
    }

    async handleAddSpeakerToSession() {
        if (!this.pendingSpeaker || !this.sessionId) return;
        this.isSaving = true;
        try {
            await saveSessionSpeaker({
                ss: {
                    Session__c: this.sessionId,
                    Speaker__c: this.pendingSpeaker.Id,
                    Role__c: this.pendingAssignment.Role__c,
                    Order__c: this.pendingAssignment.Order__c,
                    Confirmed__c: this.pendingAssignment.Confirmed__c
                }
            });
            this.close(this.pendingSpeaker.fullName);
        } catch (e) {
            this._toast('Error adding speaker', this._errorMessage(e), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    handleCancel() {
        this.close(null);
    }

    _toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    _errorMessage(error) {
        if (!error) return 'An unexpected error occurred.';
        if (error.body) {
            if (error.body.message) return error.body.message;
            if (error.body.output) {
                const errs = error.body.output.errors;
                if (errs && errs.length > 0) return errs[0].message;
                const fieldErrs = error.body.output.fieldErrors;
                if (fieldErrs) {
                    const flat = Object.values(fieldErrs).flat();
                    if (flat.length > 0) return flat[0].message;
                }
            }
            if (error.body.fieldErrors) {
                const flat = Object.values(error.body.fieldErrors).flat();
                if (flat.length > 0) return flat[0].message;
            }
        }
        if (error.message) return error.message;
        return 'An unexpected error occurred.';
    }
}
