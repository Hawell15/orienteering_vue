<template>
    <div class="show-page">
        <div class="hero">
            <TopoBackdrop />
            <div class="hero-inner">
                <div class="hero-top">
                    <div>
                        <div class="eyebrow">🏃 Grupă</div>
                        <h1 class="title">{{ group.group_name }}</h1>
                        <div class="subtitle">
                            <span v-if="group.competition">
                                <a :href="`/competitions/${group.competition.id}`">{{ group.competition.competition_name }}</a>
                            </span>
                            <template v-if="group.competition?.date">
                                <span class="dot">·</span>
                                <span>{{ group.competition.date }}</span>
                            </template>
                            <template v-if="group.competition?.distance_type">
                                <span class="dot">·</span>
                                <span>{{ group.competition.distance_type }}</span>
                            </template>
                        </div>
                        <div class="badges" v-if="group.competition?.ecn">
                            <span class="badge-pill ecn">● ECN</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="stat-cards">
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-label">Data</div>
                <div class="stat-value">{{ group.competition?.date }}</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon">🏃</div>
                <div class="stat-label">Tipul distanței</div>
                <div class="stat-value">{{ group.competition?.distance_type }}</div>
            </div>
            <div class="stat-card accent" v-if="group.competition?.ecn">
                <div class="stat-icon">⚖️</div>
                <div class="stat-label">Coeficient ECN</div>
                <div class="stat-value">{{ group.ecn_coeficient }}</div>
            </div>
            <div class="stat-card accent">
                <div class="stat-icon">🏅</div>
                <div class="stat-label">Rezultate</div>
                <div class="stat-value">{{ results.length }}</div>
            </div>
        </div>

        <div class="section">
            <div class="group-meta">
                <div>
                    <div class="group-title">Rezultate</div>
                    <div class="group-sub">
                        <span>Rang: <b>{{ group.rang || '—' }}</b></span>
                        <span class="dot">·</span>
                        <span>Clasa: <b>{{ group.category_name || '—' }}</b></span>
                    </div>
                </div>
            </div>

            <div class="results-card">
                <ResultsTable :elements="results" :hidden-columns="['group_name']" @order="orderResultTable"></ResultsTable>
            </div>

            <div v-if="isAdmin" class="results-toolbar">
                <button class="btn btn-sm btn-outline-success" :disabled="countingRang" @click="countRang">
                    {{ countingRang ? '⏳ Se recalculează…' : '🔄 Recalculează rangul' }}
                </button>
            </div>

            <div v-if="group.category_percentages?.length" class="percentages">
                <div class="percentages-title">Procente pe categorii</div>
                <div class="percentages-grid">
                    <div v-for="row in group.category_percentages" :key="row.category" class="percent-row">
                        <span class="cat">{{ row.category }}</span>
                        <span class="pct">{{ row.percent }}</span>
                        <span class="t">{{ row.time }}</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="footer-actions">
            <button class="btn btn-outline-secondary" @click="goBack">← Înapoi</button>
            <div v-if="isAdmin" class="action-group">
                <button class="btn btn-success btn-sm" @click="editElement(group)">Editează</button>
                <button class="btn btn-danger btn-sm" @click="deleteGroup(group.id)">Șterge</button>
            </div>
        </div>

        <Modal ref="modal" :group="modalElement" :isNew="false" @save="updateElement" />
    </div>
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from '@/axios'
import Modal from './Modal.vue'
import ResultsTable from '../Result/Table.vue'
import TopoBackdrop from '../shared/TopoBackdrop.vue'
import { isAdmin } from '@/currentUser'

const group = ref({})
const groupId = ref("")
const results = ref([])
const resultSorting = ref({
    "sorting[sort_by]": "place",
    "sorting[direction]": "asc"
})

const modalElement = ref({})
const modal = ref(null)
const countingRang = ref(false)

onMounted(() => {
    groupId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function countRang() {
    if (!confirm('Recalculează rangul și categoriile pentru această grupă?')) return
    countingRang.value = true
    try {
        await axios.post(`/groups/${groupId.value}/count_rang.json`)
        await getData()
        await getResults()
    } finally {
        countingRang.value = false
    }
}

async function getData() {
    const res = await axios.get(`/groups/${groupId.value}.json`)
    group.value = res.data;
}

async function getResults() {
    resultSorting.value["group_data"] = groupId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(group) {
    modalElement.value = { ...group }
    modal.value.show()
}

function updateElement(groupData, done) {
    axios.patch(`/groups/${groupData.id}.json`, { group: groupData }).then(() => {
        getData();
        done()
    })
}

function deleteGroup(id) {
    if (confirm('Esti sigur ca vrei sa stergi această grupă?')) {
        axios.delete(`/groups/${id}`).then(() => {
            window.location = document.referrer || "/groups"
        })
    }
}

function goBack() {
    window.location = document.referrer || "/groups"
}
</script>

<style scoped src="../shared/show.css"></style>
